=begin
    Copyright 2013 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

class ScansController < ApplicationController
    include ScansHelper
    include ScanGroupsHelper
    include ApplicationHelper
    include NotificationsHelper

    rescue_from ActiveRecord::RecordNotFound do
        flash[:alert] = 'The requested scan does not exist or has been deleted.'

        respond_to do |format|
            format.html { redirect_to :scans }
            format.js { render text: "window.location = '#{scans_path}';" }
        end
    end

    before_filter :authenticate_user!

    before_filter :prepare_associations,
                  only: [ :new, :new_revision, :create, :repeat ]

    # Prevents CanCan throwing ActiveModel::ForbiddenAttributesError when calling
    # load_and_authorize_resource.
    before_filter :new_scan, only: [ :create ]

    before_filter :check_scan_type_abilities, only: [ :create, :repeat ]

    load_and_authorize_resource

    # GET /scans
    # GET /scans.json
    def index
        @scan_group = ScanGroup.new
        prepare_scan_group_tab_data
        prepare_tables_data

        respond_to do |format|
            format.html # index.html.erb
            format.js { render '_tables.js' }
            format.json { render json: @scans }
        end
    end

    def errors
        @scan = find_scan( params.require( :id ) )

        respond_to do |format|
            format.text
        end
    end

    # GET /scans/1
    # GET /scans/1.json
    def show
        @scan = find_scan( params.require( :id ) )

        html_block = if render_partial?
                         proc { render @scan }
                     end

        respond_to do |format|
            format.html( &html_block )
            format.js { render '_scan.js' }
            format.json { render json: @scan }
        end
    end

    # GET /scans/1/report.html
    # GET /scans/1/report.json
    def report
        @scan = find_scan( params.require( :id ) )

        format = URI( request.url ).path.split( '.' ).last
        render layout: false,
               text: FrameworkHelper.
                           framework { |f| f.report_as format, @scan.report.object }
    end

    # GET /scans/new
    # GET /scans/new.json
    def new
        show_scan_limit_errors

        html_proc = nil
        if params[:id]
            html_proc = proc { render '_revision_form' }
            @scan = find_scan( params.require( :id ) )
        else
            @scan = Scan.new
        end

        respond_to do |format|
            format.html( &html_proc )
            format.json { render json: @scan }
        end
    end

    # GET /scans/new/1
    def new_revision
        @scan = find_scan( params.require( :id ) )

        respond_to do |format|
            format.html
        end
    end

    # POST /scans
    # POST /scans.json
    def create
        show_scan_limit_errors

        @scan.owner = current_user

        respond_to do |format|
            if !Scan.limit_exceeded? && @scan.save
                notify @scan

                format.html { redirect_to @scan }
                format.json { render json: @scan, status: :created, location: @scan }
            else
                format.html { render action: "new" }
                format.json { render json: @scan.errors, status: :unprocessable_entity }
            end
        end
    end

    # POST /scans/1/repeat
    def repeat
        show_scan_limit_errors

        @scan = find_scan( params.require( :id ) ).new_revision

        respond_to do |format|
            if @scan.repeat( strong_params )
                notify @scan

                format.html { redirect_to @scan, notice: 'Repeating the scan.' }
                format.json { render json: @scan, status: :created, location: @scan }
            else
                if errors = @scan.errors.delete( :url )
                    flash[:error] = "URL #{errors.first}."
                end
                format.html { redirect_to new_revision_scan_url( Scan.find( params[:id] ) ) }
                format.json { render json: @scan.errors, status: :unprocessable_entity }
            end
        end
    end

    # PUT /scans/1
    # PUT /scans/1.json
    def update
        @scan = find_scan( params.require( :id ) )

        update_params = params.require( :scan ).permit( :description )

        respond_to do |format|
            if @scan.update_attributes( update_params )
                format.html { redirect_to :back, notice: 'Scan was successfully updated.' }
                format.js { render '_scan.js' }
                format.json { head :no_content }
            else
                format.html { render action: "edit" }
                format.js { render '_scan.js' }
                format.json { render json: @scan.errors, status: :unprocessable_entity }
            end
        end
    end

    def update_memberships
        @scan = find_scan( params.require( :id ) )

        scan_group_ids = params.require( :scan ).
            permit( scan_group_ids: [] )[:scan_group_ids]

        respond_to do |format|
            if @scan.update_memberships( scan_group_ids )

                text = ''
                if !(group_names = @scan.scan_groups.pluck( :name ).join( ', ')).empty?
                    text = "Member of: #{group_names}"
                else
                    text = 'Left all groups.'
                end

                notify @scan, text: text

                format.html { redirect_to :back, notice: 'Scan was successfully shared.' }
                format.json { head :no_content }
            else
                format.html { render action: "edit" }
                format.json { render json: @scan.errors, status: :unprocessable_entity }
            end
        end
    end

    def share
        @scan = find_scan( params.require( :id ) )

        respond_to do |format|
            if @scan.share( params.require( :scan ).permit( user_ids: [] )[:user_ids] )

                notify @scan

                format.html { redirect_to :back, notice: 'Scan was successfully shared.' }
                format.json { head :no_content }
            else
                format.html { render action: "edit" }
                format.json { render json: @scan.errors, status: :unprocessable_entity }
            end
        end
    end

    # PUT /scans/1/pause
    def pause
        @scan = find_scan( params.require( :id ) )
        @scan.pause

        notify @scan

        respond_to do |format|
            format.js {
                if params[:render] == 'index'
                    prepare_scan_group_tab_data
                    prepare_tables_data
                    render '_tables.js'
                else
                    render '_scan.js'
                end
            }
        end
    end

    # PATCH /scans/pause
    def pause_all
        current_user.own_scans.running.each do |scan|
            scan.pause
            notify scan
        end

        respond_to do |format|
            format.js {
                prepare_scan_group_tab_data
                prepare_tables_data
                render '_tables.js'
            }
        end
    end

    # PUT /scans/1/resume
    def resume
        @scan = find_scan( params.require( :id ) )
        @scan.resume

        notify @scan

        respond_to do |format|
            format.js {
                if params[:render] == 'index'
                    prepare_scan_group_tab_data
                    prepare_tables_data
                    render '_tables.js'
                else
                    render '_scan.js'
                end
            }
        end
    end

    # PATCH /scans/resume
    def resume_all
        current_user.own_scans.paused.each do |scan|
            scan.resume
            notify scan
        end

        respond_to do |format|
            format.js {
                prepare_scan_group_tab_data
                prepare_tables_data
                render '_tables.js'
            }
        end
    end

    # PUT /scans/1/abort
    def abort
        @scan = find_scan( params.require( :id ) )
        @scan.abort

        notify @scan

        respond_to do |format|
            format.js {
                if params[:render] == 'index'
                    prepare_scan_group_tab_data
                    prepare_tables_data
                    render '_tables.js'
                else
                    render '_scan.js'
                end
            }
        end
    end

    # PATCH /scans/abort
    def abort_all
        current_user.own_scans.active.each do |scan|
            scan.abort
            notify scan
        end

        respond_to do |format|
            format.js {
                prepare_scan_group_tab_data
                prepare_tables_data
                render '_tables.js'
            }
        end
    end

    # DELETE /scans/1
    # DELETE /scans/1.json
    def destroy
        @scan = find_scan( params.require( :id ) )

        if @scan.active?
            fail 'Cannot delete an active scan, please abort it first.'
        end

        @scan.destroy
        notify @scan

        respond_to do |format|
            format.html { redirect_to scans_url }
            format.js {
                prepare_tables_data
                render '_tables.js'
            }
        end
    end

    private

    def prepare_associations
        @profiles         = current_user.available_profiles
        @dispatchers      = current_user.available_dispatchers.alive
        @grid_dispatchers = @dispatchers.grid_members
    end

    def new_scan
        @scan = Scan.new( strong_params )
    end

    def strong_params
        if params[:scan][:type] == 'grid' || params[:scan][:type] == 'remote'
            params[:scan][:dispatcher_id] = params.delete( params[:scan][:type].to_s + '_dispatcher_id' )
        end

        if params[:scan][:dispatcher_id] == 'load_balance'
            params[:scan][:dispatcher_id] = current_user.available_dispatchers.preferred.id
        end

        allowed = [ :restrict_to_revision_sitemaps, :extend_from_revision_sitemaps ]
        if (sitemap_option = params[:scan].delete( :sitemap_option )) &&
            allowed.include?( sitemap_option.to_sym )
            params[:scan][sitemap_option] = true
        end

        params.delete( 'grid_dispatcher_id' )
        params.delete( 'remote_dispatcher_id' )

        params.require( :scan ).
            permit( :url, :description, :type, :instance_count, :profile_id,
                    { user_ids: [] }, { scan_group_ids: [] }, :dispatcher_id,
                    :restrict_to_revision_sitemaps, :extend_from_revision_sitemaps )
    end

    def find_scan( id )
        s = Scan.find( params[:id] )
        params[:overview] == 'true' ? s.act_as_overview : s
    end

    def check_scan_type_abilities
        return if can? "perform_#{params[:scan][:type]}".to_sym, Scan

        flash[:error] = "You don't have #{params[:scan][:type]} scan privileges."
        redirect_to :back
    end

    def show_scan_limit_errors
        if Scan.limit_exceeded?
            do_not_fade_out_messages
            flash[:error] = 'Maximum scan limit has been reached, please try again later.'
        end

        if current_user.scan_limit_exceeded?
            do_not_fade_out_messages
            flash[:error] = 'Your scan limit has been reached, please try again later.'
        end
    end

end
