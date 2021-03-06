# -*- encoding : utf-8 -*-

class HomeController < ApplicationController
  respond_to :html, :js

  include LayoutHelper #TODO: Why we need this here? (otherwise accessible_postings will not be loaded)

  # Display the top pages on the home-page
  def index
    @blog = Blog.public_blogs.where(:title => t(:news) ).first
    if @blog
      @postings = @blog.postings_for_user_and_mode(current_user,draft_mode)
      .desc(:created_at)
      .paginate(
        :page => params[:page],
        :per_page => CONSTANTS['paginate_postings_per_page'].to_i
      )
    end
    respond_to do |format|
       format.js {
         @path = blog_path(@blog, :page => (params[:page] ? (params[:page].to_i+1) : 2))
         render :index
       }
       format.html { render :index }
    end
  end

  # Respond with an atom rss-feed
  # GET /feed
  def rss_feed
    @feed_items = []
    Blog.public_blogs.each do |blog|
      blog.postings.rss_items.desc(:updated_at).each do |posting|
        if posting.public?
          @feed_items << FeedItem.new(posting.title, posting.body, posting.updated_at, posting_url(posting), posting)
          posting.comments.each do |comment|
            @feed_items << FeedItem.new( ("%s %% %s" % [posting.title,comment.name]), comment.comment, comment.updated_at, posting_url(posting),comment)
          end
        end
      end
    end

    Page.rss_items.asc(:updated_at).each do |page|
      @feed_items << FeedItem.new(page.title,page.body,page.updated_at,page_url(page),page)
      page.comments.each do |comment|
        @feed_items << FeedItem.new( ("%s %% %s" % [page.title,comment.name]), comment.comment, comment.updated_at, page_url(page),comment)
      end
    end

    @feed_items.sort! {|a,b| a.updated_at <=> b.updated_at}
    @feed_items
  end

  # GET /switch_locale/:locale
  def set_locale
    I18n.locale=params[:locale].to_sym
    cookies.permanent[:lang] = params[:locale]
    target = request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : root_path
    redirect_to target, :notice => t(:language_switched_to, :lang => t("locales.#{params[:locale]}")).html_safe
  end

  # GET /draft_mode/:mode
  def set_draft_mode
    change_draft_mode(params[:mode])
    target = request.env['HTTP_REFERER'] ? request.env['HTTP_REFERER'] : root_path
    redirect_to target, :notice => t(:draft_mode_switched_to, :mode => params[:mode] == "1" ? t(:is_on) : t(:is_off)).html_safe
  end
  
  # GET /tag/:tag
  def tags
    @postings ||= accessible_postings(params[:tag],current_role).order([:created_at, :desc])
  end

end
